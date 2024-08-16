# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# iTerm2 tab and window title
if [ $ITERM_SESSION_ID ]; then
  # Set tab title to current directory and set window title to full path
  # the $PROMPT_COMMAND environment variable is executed every time a command is run
  export PROMPT_COMMAND='echo -ne "\033]1;${PWD##*/}\007" && echo -ne "\033]2;${PWD}\007"; ':"$PROMPT_COMMAND";
fi

function iterm2_print_user_vars() {
  iterm2_set_user_var kubecontext $(kubectl config current-context)
}

function iterm2_print_user_vars() {
  iterm2_set_user_var kubecontext $(kubectl config current-context):$(kubectl config view --minify --output 'jsonpath={..namespace}')
}

# script to kick common Tanzu Application Platform installed components
alias kf=kungfu
function kungfu() {
    BLUE_BOLD='\033[1;34m'
    NC='\033[0m' # No Color

    if [ "$1" = "nsp" ]; then
        kctrl app kick -a provisioner -n tap-namespace-provisioning -y
        kctrl package installed kick -i namespace-provisioner -n tap-install -y
    elif [ "$1" = "tap" ]; then
        kctrl package installed kick -i "$1" -n tap-install -y
    elif [ "$1" = "package" ]; then
        if [ -z "$2" ]; then
            echo "Usage: kungfu package <package-name>"
        else
            kctrl package installed kick -i "$2" -n tap-install -y
        fi
    elif [ "$1" = "sync" ]; then
        kctrl app kick -a sync -n tanzu-sync -y
    elif [ "$1" = "post-install" ]; then
        kctrl app kick -a tap-post-install-gitops -n tap-install -y
    elif [ "$1" = "install" ]; then
        kctrl app kick -a tap-install-gitops -n tap-install -y
    elif [ "$1" = "chop" ]; then
        kctrl app kick -a sync -n tanzu-sync -y
        kctrl package installed kick -i tap -n tap-install -y
        kctrl app kick -a tap -n tap-install -y
        kctrl app kick -a tap-post-install-gitops -n tap-install -y
        kctrl app kick -a provisioner -n tap-namespace-provisioning -y
    elif [ "$1" = "help" ]; then
        echo " "
        echo -e "${BLUE_BOLD}Available kungfu commands:${NC}"
        echo "  kungfu tap                     - Run kctrl package installed kick -i tap -n tap-install -y"
        echo "  kungfu nsp                     - Run kctrl app kick -a provisioner -n tap-namespace-provisioning"
        echo "  kungfu package <package-name>  - Run kctrl package installed kick -i <package> -n tap-install"
        echo "  kungfu sync                    - Run kctrl app kick -a sync -n tanzu-sync"
        echo "  kungfu install                 - Run kctrl app kick -a tap-install-gitops -n tap-install"
        echo "  kungfu post-install            - Run kctrl app kick -a tap-post-install-gitops -n tap-install"
        echo "  kungfu chop                    - Kicks the sync app, tap package, tap app, and post install and NSP apps to reconcile all change"
    else
        echo "Unknown command: $1"
        echo "Use 'kungfu help' to see all available commands."
    fi
}

# Script to print out the schema for Tanzu Application Platform Packages 
function tap-schema {
  IFS=$'\n'
  if [ $# -eq 0 ]
    then
        echo "tanzu-schema <component short name>"
        echo "  Components:"
        for i in $(tanzu package installed list -n tap-install 2>/dev/null);  do
          https://broadcom.zoom.us/j/92566312090?pwd=MTvgECuvYRT2jjktDRQhWea2MVEKov.1 component=$(echo $i | grep -v NAME | sed 's/^ *//g' | awk '{print $1}')
           if [ -z $component ]
           then
             :
           else
             echo "      $component"
           fi
        done
    else
        temp=$(tanzu package installed list -n tap-install 2>/dev/null | grep $1 | sed 's/^ *//g')
        package=$(echo $temp | awk '{print $2}')
        version=$(echo $temp | awk '{print $3}')
        echo "Values Schema for $1"
        for i in $(tanzu -n tap-install package available get $package/$version --values-schema 2>/dev/null); do
          if [ -z $i ]
          then
            :
          else
            echo $i
          fi
        done
    fi
}

#oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=( web-search)
source $ZSH/oh-my-zsh.sh

HOMEBREW_NO_AUTO_UPDATE=1

#History setup
HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000
SAVEHIST=$HISTSIZE
alias h=history

#Alias Setup
alias k=kubecolor
alias t=tanzu
alias kd="kubectl --dry-run=client -o yaml"
alias ka="kubectl apply -f"
alias kD="kubectl delete --grace-period=0 --force"
#alias kn="kubectl config set-context --current --namespace"
alias kctx="kubectx"
alias kns="kubens"
alias tf=terraform
alias openpackage=pull_and_code $1
alias knodes="kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'"
alias netshoot="kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot"

[ -f fubectl.source ] && source fubectl.source

# script to pull code from a TAP bundle and open a vscode instance with it loaded
function pull_and_code () {
  imgpkg pull -b $(kubectl get app $1 -n tap-install -ojson | jq -r '.spec.fetch[0].imgpkgBundle.image') -o ~/dev/tap-packages/$1 && code ~/dev/tap-packages/$1
}


export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
#alias ls='ls -l -GFh'
alias l="exa --long --header --git"

source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
PROMPT='$(kube_ps1)'$PROMPT

alias c=clear

#source <(kubectl completion zsh)
#source <(stern --completion=zsh)
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ /usr/local/bin/kubectl ]] && source <(kubectl completion zsh) # auto complete

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

#iTerm Themes
source /usr/local/opt/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/castleje/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/castleje/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/castleje/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/castleje/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="$PATH:/Users/castleje/dev/cloudgate-automation"
alias awscreds='updateAwsCreds.sh'

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
