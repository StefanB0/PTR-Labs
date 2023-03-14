build-linux:
	mix deps.get
	sudo docker pull alexburlacu/rtp-server:faf18x
build:
	mix deps.get
	docker pull alexburlacu/rtp-server:faf18x
run-linux:
	sudo docker run -p 4000:4000 -d alexburlacu/rtp-server:faf18x
	mix run --no-halt
run:
	docker run --name faf18x-server-rtp -p 4000:4000 -d alexburlacu/rtp-server:faf18x
	mix run --no-halt
stop:
	sudo docker stop faf18x-server-rtp
	sudo docker rm faf18x-server-rtp