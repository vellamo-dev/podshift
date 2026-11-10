# failed-services

Lists all _podshift_ user services that have failed to start.

This command lists all user-level *systemd* services that have failed to start or crashed during the session. It scopes the query to the *podshift* user services rather than system-wide ones. The output is printed directly to the terminal as plain text without opening an interactive view.

## Usage `(root)`

```shell
podshift failed-services
```
## Usage `(podshift)`

```shell
failed-services
```
