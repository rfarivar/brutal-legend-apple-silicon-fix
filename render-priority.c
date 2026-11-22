#include <pthread.h>
#include <sched.h>
#include <stdio.h>
#include <string.h>

static const char render_thread_name[] = "Render Thread";
static const int render_priority = 47;

static int set_priority(pthread_t thread, int policy,
                        const struct sched_param *params)
{
    if (policy == SCHED_OTHER && params && params->sched_priority < render_priority) {
        char name[64];
        if (pthread_getname_np(thread, name, sizeof(name)) == 0 &&
            strcmp(name, render_thread_name) == 0) {
            struct sched_param boosted = *params;
            boosted.sched_priority = render_priority;
            int result = pthread_setschedparam(thread, policy, &boosted);
            if (result == 0) {
                return 0;
            }
        }
    }
    return pthread_setschedparam(thread, policy, params);
}

static int set_name(const char *name)
{
    int result = pthread_setname_np(name);
    if (result == 0 && strcmp(name, render_thread_name) == 0) {
        pthread_t thread = pthread_self();
        int policy;
        struct sched_param params;
        if (pthread_getschedparam(thread, &policy, &params) == 0 &&
            policy == SCHED_OTHER && params.sched_priority < render_priority) {
            int previous = params.sched_priority;
            params.sched_priority = render_priority;
            int error = pthread_setschedparam(thread, policy, &params);
            if (error == 0) {
                fprintf(stderr, "Buddha Render Thread priority: %d -> %d\n",
                        previous, render_priority);
            } else {
                fprintf(stderr, "Buddha Render Thread priority: %s\n", strerror(error));
            }
        }
    }
    return result;
}

__attribute__((used, section("__DATA,__interpose")))
static const struct {
    const void *replacement;
    const void *original;
} interpositions[] = {
    { (const void *)set_name, (const void *)pthread_setname_np },
    { (const void *)set_priority, (const void *)pthread_setschedparam },
};
