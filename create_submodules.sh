#!/bin/bash


function create_submodule {
	local REPO=$1
	local MODULE_FOLDER=$2;
	local SWITH_BRANCH=$3;
	
	echo submodule add $REPO $MODULE_FOLDER
	git submodule add $REPO $MODULE_FOLDER
	
	local WORKING_DIR=$PWD
	if [ $SWITH_BRANCH == true ]
	then
		cd $MODULE_FOLDER
		git checkout gloomywood2
		cd $WORKING_DIR
	fi
}

#Modules
PARENT_FOLDER="modules"
mkdir $PARENT_FOLDER
create_submodule http://source.mungo.io/modules/brl.git $PARENT_FOLDER/brl true
create_submodule http://source.mungo.io/modules/dom.git $PARENT_FOLDER/dom true
create_submodule http://source.mungo.io/modules/harmony.git $PARENT_FOLDER/harmony true
create_submodule http://source.mungo.io/modules/mojo.git $PARENT_FOLDER/mojo true
create_submodule http://source.mungo.io/modules/monkey.git $PARENT_FOLDER/monkey true
create_submodule http://source.mungo.io/modules/opengl.git $PARENT_FOLDER/opengl true
create_submodule http://source.mungo.io/modules/os.git $PARENT_FOLDER/os true
create_submodule http://source.mungo.io/modules/reflection.git $PARENT_FOLDER/reflection true
create_submodule http://source.mungo.io/modules/trans.git $PARENT_FOLDER/trans true

#Targets
PARENT_FOLDER="targets"
mkdir $PARENT_FOLDER

create_submodule http://source.mungo.io/targets/android.git $PARENT_FOLDER/android false
create_submodule http://source.mungo.io/targets/ouya.git $PARENT_FOLDER/android_ouya false
create_submodule http://source.mungo.io/targets/cpptool.git $PARENT_FOLDER/cpptool true
create_submodule http://source.mungo.io/targets/flash.git $PARENT_FOLDER/flash false
create_submodule http://source.mungo.io/targets/glfw.git $PARENT_FOLDER/glfw false
create_submodule http://source.mungo.io/targets/glfw3.git $PARENT_FOLDER/glfw3 true
create_submodule http://source.mungo.io/targets/glfw-steam.git $PARENT_FOLDER/glfw_steam false
create_submodule http://source.mungo.io/targets/html5.git $PARENT_FOLDER/html5 true
create_submodule http://source.mungo.io/targets/ios.git $PARENT_FOLDER/ios false
create_submodule http://source.mungo.io/targets/javatool.git $PARENT_FOLDER/javatool false
create_submodule http://source.mungo.io/targets/psm.git $PARENT_FOLDER/psm false
create_submodule http://source.mungo.io/targets/win8.git $PARENT_FOLDER/winrt_win8 false
create_submodule http://source.mungo.io/targets/winphone8.git $PARENT_FOLDER/winrt_winphone8 false
create_submodule http://source.mungo.io/targets/xna.git $PARENT_FOLDER/xna false
create_submodule ssh://git@GloomyStation:20509/~/Dependencies/targets/ps4.git $PARENT_FOLDER/ps4 false
create_submodule ssh://git@GloomyStation:20509/~/Dependencies/targets/xboxone.git $PARENT_FOLDER/xboxone false

#Samples
create_submodule http://source.mungo.io/docs/samples.git samples false

$SHELL