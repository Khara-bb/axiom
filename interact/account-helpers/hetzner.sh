#!/bin/bash

AXIOM_PATH="$HOME/.axiom"
source "$AXIOM_PATH/interact/includes/vars.sh"

appliance_name=""
appliance_key=""
appliance_url=""
token=""
region=""
provider=""
size=""
email=""

BASEOS="$(uname)"
case $BASEOS in
'Linux')
    BASEOS='Linux'
    ;;
'FreeBSD')
    BASEOS='FreeBSD'
    alias ls='ls -G'
    ;;
'WindowsNT')
    BASEOS='Windows'
    ;;
'Darwin')
    BASEOS='Mac'
    ;;
'SunOS')
    BASEOS='Solaris'
    ;;
'AIX') ;;
*) ;;
esac

if [[ "$acc" == "n" ]]; then
    echo -e "${Blue}Launching browser with signup page...${Color_Off}"
    if [ $BASEOS == "Mac" ]; then
        open "https://accounts.hetzner.com/signUp"
    elif [ $BASEOS == "Linux" ]; then
        OS=$(lsb_release -i | awk '{ print $3 }')
        if ! command -v lsb_release &>/dev/null; then
            OS="unknown-Linux"
            BASEOS="Linux"
        fi
        if [ $OS == "Arch" ] || [ $OS == "ManjaroLinux" ]; then
            sudo pacman -Syu xdg-utils --noconfirm
        else
            sudo apt install xdg-utils -y
        fi
        xdg-open "https://accounts.hetzner.com/signUp"
    fi
fi

function setuphetzner() {
    echo -e "${BGreen}Sign up for an account using this link for free credit: https://accounts.hetzner.com/signUp\nObtain a personal access token from: https://cloud.linode.com/profile/tokens${Color_Off}"
    echo -e -n "${Blue}Do you already have a Hetzner account? y/n ${Color_Off}"
    read acc

    echo -e -n "${Green}Please enter your token (required): \n>> ${Color_Off}"
    read token
    while [[ "$token" == "" ]]; do
        echo -e "${BRed}Please provide a token, your entry contained no input.${Color_Off}"
        echo -e -n "${Green}Please enter your token (required): \n>> ${Color_Off}"
        read token
    done

    echo -e -n "${Green}Please enter your default region: (Default 'eu-central', press enter) \n>> ${Color_Off}"
    read region
    if [[ "$region" == "" ]]; then
        echo -e "${Blue}Selected default option 'eu-central'${Color_Off}"
        region="eu-central"
    fi
    echo -e -n "${Green}Please enter your default size: (Default 'g6-standard-1', press enter) \n>> ${Color_Off}"
    read size
    if [[ "$size" == "" ]]; then
        echo -e "${Blue}Selected default option 'g6-standard-1'${Color_Off}"
        size="cx22"
    fi

    echo -e -n "${Green}Please enter your GPG Recipient Email (for encryption of boxes): (optional, press enter) \n>> ${Color_Off}"
    read email

    echo -e -n "${Green}Would you like to configure connection to an Axiom Pro Instance? Y/n (Must be deployed.) (optional, default 'n', press enter) \n>> ${Color_Off}"
    read ans

    if [[ "$ans" == "Y" ]]; then
        echo -e -n "${Green}Enter the axiom pro instance name \n>> ${Color_Off}"
        read appliance_name

        echo -e -n "${Green}Enter the instance URL (e.g \"https://pro.acme.com\") \n>> ${Color_Off}"
        read appliance_url

        echo -e -n "${Green}Enter the access secret key \n>> ${Color_Off}"
        read appliance_key
    fi

    data="$(echo "{\"do_key\":\"$token\",\"region\":\"$region\",\"provider\":\"hetzner\",\"default_size\":\"$size\",\"appliance_name\":\"$appliance_name\",\"appliance_key\":\"$appliance_key\",\"appliance_url\":\"$appliance_url\", \"email\":\"$email\"}")"

    echo -e "${BGreen}Profile settings below: ${Color_Off}"
    echo $data | jq
    echo -e "${BWhite}Press enter if you want to save these to a new profile, type 'r' if you wish to start again.${Color_Off}"
    read ans

    if [[ "$ans" == "r" ]]; then
        $0
        exit
    fi

    echo -e -n "${BWhite}Please enter your profile name (e.g 'personal', must be all lowercase/no specials)\n>> ${Color_Off}"
    read title

    if [[ "$title" == "" ]]; then
        title="personal"
        echo -e "${Blue}Named profile 'personal'${Color_Off}"
    fi

    echo $data | jq >"$AXIOM_PATH/accounts/$title.json"
    echo -e "${BGreen}Saved profile '$title' successfully!${Color_Off}"
    $AXIOM_PATH/interact/axiom-account $title
    echo -e -n "${Yellow}Would you like me to open a ticket to get an image increase to 25GB for you (you only need to do this once)?${Color_Off} [y]/n >> "
    read acc

    if [[ "$acc" == "" ]]; then
        acc="y"
    fi

    if [[ "$acc" == "y" ]]; then

        curl https://api.linode.com/v4/support/tickets -H "Content-Type: application/json" -H "Authorization: Bearer $token" -X POST -d '{ "description":  "Hello! I have recently installed the axiom framework http://github.com/pry0cc/axiom and would like to request an image increase to 25GB please for the purposes of bulding the packer image. Thank you have a great day! - This request was automatically generated by Axiom", "summary": "Image increase request to 25GB for Axiom" }'
        echo ""
        echo -e "${Green}Opened a ticket with Linode support! Please wait patiently for a few hours and when you get an increase run 'axiom-build'!${Color_Off}"
        echo "View open tickets at: https://cloud.linode.com/support/tickets"
    fi
}

setuphetzner
