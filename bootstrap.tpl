#!/bin/bash

sudo apt-get -y update

sudo apt-get -y install \
		    apt-transport-https \
		    	        ca-certificates \
						    curl \
						    		        gnupg-agent \
												    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository --yes \
		   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
		   	      $(lsb_release -cs) \
			      	         stable"

sudo apt-get -y update

sudo apt-get -y install docker-ce docker-ce-cli containerd.io unzip

wget https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip

unzip terraform_0.11.13_linux_amd64.zip

sudo mv terraform /usr/local/bin/
