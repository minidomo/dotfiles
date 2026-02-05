eval "$(just --completions bash)"
eval "$(gh completion -s bash)"
eval "$(rustup completions bash)"
eval "$(rustup completions bash cargo)"
eval "$(task --completion bash)"
eval "$(minikube completion bash)"
eval "$(kubectl completion bash)"
eval "$(docker completion bash)"

complete -C aws_completer aws

# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
PROMPT_COMMAND=${PROMPT_COMMAND:+"$PROMPT_COMMAND; "}'printf "\e]9;9;%s\e\\" "`cygpath -w "$PWD" -C ANSI`"'

eval "$(starship init bash)"
# PS1='$(prmt --code $? "\n{path:blue} {git:#666666}\n{ok:purple}{fail:red} ")'
