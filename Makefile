.PHONY: _deploy
_deploy:
	helm upgrade --install --tiller-namespace $(NAMESPACE) --namespace $(NAMESPACE) \
		--set image=docker.k8s.jobteaser.net/coretech/ci-connector:master \
		--set-file script=$(CURDIR)/bin/$(NAME)/main.rb \
		-f $(CURDIR)/bin/$(NAME)/values.yaml \
		$(NAME) \
		jobteaser/ci-connector

.PHONY:
# Deploy datadog connector
datadog:
	$(MAKE) _deploy NAME=$@

.PHONY:
# Deploy grafana connector
grafana:
	$(MAKE) _deploy NAME=$@ NAMESPACE=coretech

.PHONY: release-notification
# Deploy release-notification connector
release-notification:
	$(MAKE) _deploy NAME=$@ NAMESPACE=jobteaser

.PHONY: help
.DEFAULT_GOAL:= help
help:
	@echo Usage:
	@sed  -E '/^#.*/ {N; s/^#\s*(.*)\n(.*):.*$$/make \2: \x1b[37m\1\x1b[0m/};t;d' Makefile
