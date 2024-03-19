# Prerequisties  

1) Register a __Domain/Subdomain__ in your DNS (like 'subdomain.domain.tld')  

       # checking your domain in terminal should resolve your domain:  
       host subomain.domain.tld 

2) __Clone this repo__ and create your own copy/repo of it
   NOTE: You need a public repo 
   The customization script (customize-jitsi.sh) relies repository structure as follows.  

        +-- ./
        |   +-- apps
        |   |   +-- jitsi-meet 
        |   |   |   +-- configs
        |   |   |   +-- custom-frontend
        |   |   |   |   +-- subdomain.domain.tld (folder) 
        |   |   |   |   |   +-- css
        |   |   |   |   |   +-- images
        |   |   |   |   |   +-- static
        |   |   |   |   |   |   +-- privacy-policy-jitsi_de.html
        |   |   |   |   |   |   +-- welcome.html
        |   |   |   |   |   |   +-- close3.html
        |   |   |   +-- helper

3) Check the __template html files__ ./apps/jitsi-meet/custom-frontend/subdomain.domain.tld 
   and customize them to your belongings  
   
   __Note__: fill the html templates 'legal-notice_de.html" and "privacy-policy-jitsi_de.html" with your content!

    - optional: customize __header.jpg/png__ and your colors (maybe after the first build)
    - optional: change settings for the jitsi interface in __'interface_confg-template.js'__
    - optional: change settings (headerTitle, headerSubtitle) in the language files __'main.json'__ and __'main-de.json'__

4) copy 'jitsi.env.template' to 'jitsi.env'

5) fill your jitsi.env with your credentials and settings  
   NOTE: jitsi.env gets ignored by .gitignore  
   
6) __Create Your Setup File__ (cloud_config.yaml)

    - run setup.sh in your local environment  
      NOTE: this script fills the placeholder you set in your jitsi.env 
      
    - you get an cloud-config.yaml with your settings/credentials 
      NOTE: check if there are settings missing ( look for {{placeholders}} in your .yaml )

7) Build the Server  
    - see the gif animation ( this setup bases on Hetzner Cloud Config )  
    - copy the content of your cloud-config.yaml to the clipboard
    - run installation on Hetzner

    ![Manual](./docs/howto_use-hetzner-jitzi-image.gif "How to setup Jitsi on Hetzner.")

8) login as __root__ (not your created user) on cli first!  
   NOTE: Use SSH-Key from Hetzner Setup (if you have defined another in your .yaml)  
   NOTE: Logging in with root first triggers the "one click installer"  

       ssh -i /path/to/your/key root@<ip-address>)


    - the __"One-Click-Installer"__ will run and ask for your:
    - Server-Domain (subdomain.domain.tld)  
    - Your Mail-Address for SSL-Certificate (Let's encrypt)  

    - After running successfully the One-Click-Installer, additionally run the customization script
      NOTE: the scripts gets 'curled' from your public repo

          sh /opt/apps/jitsi-meet/helper/customize-jitsi.sh  


        ![Manual](./docs/howto_setup-jitsi-cli.gif "How to setup Jitsi on Hetzner.")

9) Further maintenance  
   After successfully run the setup you won't be able to login as root again.  
   Use your jitsi-user (defined in your cloud-config.yaml).  