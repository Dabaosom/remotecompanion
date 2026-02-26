/*
 * rc-root - Setuid root helper for RemoteCommand
 * Executes shell commands as root when called from mobile user
 *
 * Must be installed with: chown root:wheel rc-root && chmod 4755 rc-root
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/wait.h>
#include <CoreFoundation/CoreFoundation.h>

extern char **environ;

// Read custom paths from preferences plist


int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: rc-root <command> [args...]\n");
        return 1;
    }

    // Ensure we're running as root (setuid should handle this)
    if (setuid(0) != 0) {
        fprintf(stderr, "Error: Failed to setuid to root\n");
        return 1;
    }

    if (setgid(0) != 0) {
        fprintf(stderr, "Error: Failed to setgid to root\n");
        return 1;
    }

    // Build command string from all arguments for shell execution
    size_t total_len = 0;
    for (int i = 1; i < argc; i++) {
        total_len += strlen(argv[i]) + 1;
    }

    char *cmd = malloc(total_len + 1);
    if (!cmd) {
        fprintf(stderr, "Error: Memory allocation failed\n");
        return 1;
    }

    cmd[0] = '\0';
    for (int i = 1; i < argc; i++) {
        strcat(cmd, argv[i]);
        if (i < argc - 1) {
            strcat(cmd, " ");
        }
    }

    // Use posix_spawn to run sh -c "command"
    // Try rootless path first, fall back to standard path
    pid_t pid;
    const char *shell_path = "/var/jb/usr/bin/sh";

    // Check if rootless shell exists, otherwise use standard path
    if (access(shell_path, X_OK) != 0) {
        shell_path = "/bin/sh";
    }

    // Build PATH with custom paths prepended
    // Build PATH
    char *path_env = strdup("PATH=/var/jb/usr/local/bin:/var/jb/usr/bin:/var/jb/bin:/var/jb/usr/sbin:/var/jb/sbin:/usr/bin:/bin:/usr/sbin:/sbin");

    // Set up environment
    char *new_env[] = {
        path_env,
        "HOME=/var/root",
        NULL
    };

    char *shell_args[] = {(char *)shell_path, "-c", cmd, NULL};

    int status = posix_spawn(&pid, shell_path, NULL, NULL, shell_args, new_env);

    if (status != 0) {
        fprintf(stderr, "Error: posix_spawn failed with status %d\n", status);
        free(cmd);
        free(path_env);
        return 1;
    }

    // Wait for child process
    int exit_status;
    waitpid(pid, &exit_status, 0);

    free(cmd);
    free(path_env);

    if (WIFEXITED(exit_status)) {
        return WEXITSTATUS(exit_status);
    }

    return 1;
}
