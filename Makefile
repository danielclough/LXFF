help:
	@echo "\nmake help\n\tThis help message.\n\nmake create\n\tCreate LXC and Make App avalible on Desktop and Menu.\n\nmake test-x\n\tEyes watch cursor if X is properly configured.\n\nmake test-gpu\n\tGears if GPU is working.\n\nmake test-audio\n\tSound if PulseAudio is working.\n\nmake clean\n\tRemove Container and Profile\n"

create:
	@bash create.sh && echo "\nLXFF Created!\n"

test-x:
	@lxc exec x11-firefox -- sudo --user ubuntu --login -- glxinfo -B
	@lxc exec x11-firefox -- sudo --user ubuntu --login -- xeyes

test-gpu:
	### GPU ###
	@lxc exec x11-firefox -- sudo --user ubuntu --login -- nvidia-smi
	@lxc exec x11-firefox -- sudo --user ubuntu --login -- glxgears

test-audio:
	### Audio ###
	### push sound to lxc ###
	### [original](https://freewavesamples.com/alesis-s4-night-vox-c3) ###
	@lxc file push ./sound.wav x11-firefox/home/ubuntu/sound.wav

	@lxc exec x11-firefox -- sudo --user ubuntu --login -- pactl info
	@lxc exec x11-firefox -- sudo --user ubuntu --login -- bash -c "export PULSE_LOG=4 && paplay /home/ubuntu/sound.wav"
	@echo 'If no audio -> Watch "`pavucontrol` >> Playback" while audio is playing and see if it shows up.'

clean:
	@lxc stop x11-firefox
	@lxc rm x11-firefox
	@lxc profile rm x11