
build-aio:
	@if [ -z "${submodule}" ] ; then \
		echo "Please provide the name of the submodule service to build (submodule=<submodule service name>)"; \
		exit 1; \
	fi

	@if [ "${context}" != "prod" -a "${context}" != "dev" -a "${context}" != "tests" ] ; then \
		echo "Please provide a context for this build (context=<desired_context> , possible options: prod, dev, tests)"; \
		exit 1; \
	fi

	echo "Building submodule '${submodule}' for ${context} context"

	@docker build -f ./Dockerfile.AIO ./ --tag openslides-${submodule}-${context} --build-arg CONTEXT=${context} --target ${context} ${args}

build-dev:
	./make-localhost-cert.sh
	make build-aio context=dev submodule=proxy

# docker build -t openslides-proxy-dev -f Dockerfile.dev .

run-tests:
	echo "Proxy has no tests"