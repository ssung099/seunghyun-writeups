# Shellshock (CVE-2014–6271)

## Summary
Shellshock, also known as Backdoor, is a vulnerability in the GNU Bash shell that allows attackers to execute arbitrary commands by crafting malicious environment variables. The vulnerability arises from incorrect parsing of function definitions, which allows additional commands appended after the function body to be interpreted and executed as well.

Artifacts:
- `script.sh`: the bash script that executes commands through maliciously crafted environment variables.
- `vulnerable_bash`: the vulnerable version of bash compiled from source before the patch. To be used with `script.sh` to demonstrate the vulnerability.

## Context
<!-- Write about Bash -->

Bash contains a "function export" through environment variables that allows one Bash process to easily share command scripts with other Bash process that it executes. When a new Bash process starts, it would scan for `() { ... }` and import the content of curly braces as function definitions. 

## Vulnerability
The main vulnerability with versions of Bash up to 4.3 was that it parsed the input to end of the string rather than to the closing curly brace of a function definition assigned to an environment variable.

In bash-4.1, the `parse-string` function used the loop `while (*(bash_input.location.string))` which iterated until you reached a null byte `\0` in the string.

The injected command would also execute with the same privileges as the new bash process, which could cause severe impacts if possessing elevated privileges.

## Exploitation
By utilizing the fact that `parse-string` continues to parse until the end of the string, you can exploit this vulnerability by appending commands to the end of the function definition using `;` as a command separator. Bash allows the usage of `;` to separate multiple commands written in one line. 

Consider the following environment variable `x = () { :; }; echo Hello`.
The new Bash process would recognize this as a function definition since it has the format `() { ... }` and try to parse it.
It would add the contents within the braces as a function definition. In this case, `:;` is a minimal function that does not do anything so it would not execute anything.
Since there are still characters left in the string, it would continue to parse and execute any subsequent commands. Therefore, it would execute `echo Hello` as an immediate shell command the moment it starts up.

## Remediation
The remediation for this vulnerability was to ensure that only one command was to be parsed and executed. Starting from Bash 4.4, flags `SEVAL_FUNCDEF` and `SEVAL_ONECMD` were added. `SEVAL_FUNCDEF` ensured that the input only took the function definition form `() { ... }`. In addition, `SEVAL_ONECMD` ensured that only one syntactic unit was processed, eliminating the possibility of chain commands with `;`.