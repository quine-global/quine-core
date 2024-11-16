This is where you would place keys specific to the infrastructure (machines) you are 
deploying this structure to.

* `mainframe.pub` will be used for decrypting secrets, so it can be any key you like as long as it is able to decrypt the `age` secret files.
* `authorized_keys` directory represents any keys you wish to be able to access the machine with, using SSH passwordless authentication.
* `known_hosts` is optional but may be nice for improving or automating SSH operations.

Any file in `authorized_keys` or `known_hosts` should be a `.pub` file which is just plain text and no newlines.
