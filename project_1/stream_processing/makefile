build-linux:
	mix deps.get
	sudo docker pull alexburlacu/rtp-server:faf18x
build:
	mix deps.get
	docker pull alexburlacu/rtp-server:faf18x
docker:
	docker run --name faf18x-server-rtp -p 4000:4000 -d alexburlacu/rtp-server:faf18x
run:
	mix run --no-halt