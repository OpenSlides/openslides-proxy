build-dev:
	./make-localhost-cert.sh
	docker build -t openslides-proxy-dev -f Dockerfile.dev .

build-dev-fullstack: | build-dev