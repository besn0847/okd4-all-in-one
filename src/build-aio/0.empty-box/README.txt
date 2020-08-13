0/ Create an empty box in Virtual box with correct set-up

1/ Export the box 
	vagrant package --base empty --output empty.box

2/ Import the new box into vagrant
	vagrant box add empty.box --name empty
 

