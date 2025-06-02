SERVICE=proxy 

build-dev:
	./make-localhost-cert.sh
	bash ../dev/scripts/makefile/build-service.sh $(SERVICE) dev

build-prod:
	bash ../dev/scripts/makefile/build-service.sh $(SERVICE) prod

build-test:
	bash ../dev/scripts/makefile/build-service.sh $(SERVICE) tests

run-tests:
	echo "Proxy has no tests"