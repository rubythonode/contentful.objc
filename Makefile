__SIM_ID=`xcrun simctl list|egrep -m 1 '$(SIM_NAME) \([^(]*\) \([^(]*\)$$'|sed -e 's/.* (\(.*\)) (.*)/\1/'`
SIM_NAME=iPhone 5s
SIM_ID=$(shell echo $(__SIM_ID))

ifeq ($(strip $(SIM_ID)),)
$(error Could not find $(SIM_NAME) simulator)
endif

WORKSPACE=ContentfulSDK.xcworkspace

.PHONY: all open clean clean_simulators doc example example-static pod really-clean static-lib test kill_simulator

open:
	open ContentfulSDK.xcworkspace

clean: clean_simulators
	rm -rf build Examples/UFO/build Examples/*.zip compile_commands.json .gutter.json
	rm -rf Examples/UFO/Distribution/ContentfulDeliveryAPI.framework

clean_pods:
	rm -rf Pods/

really_clean: clean
	rm -rf $(HOME)/Library/Developer/Xcode/DerivedData/*

clean_simulators:
	xcrun simctl erase all

all: test example-static

pod:
	bundle exec pod install
	xcversion select 7.3.1
	xcrun bitcode_strip -r Pods/Realm/core/librealm-ios.a -o Pods/Realm/core/librealm-ios.a

example:
	set -o pipefail && xcodebuild clean build -workspace $(WORKSPACE) \
		-scheme ContentfulDeliveryAPI \
		-sdk iphonesimulator -destination 'id=$(SIM_ID)'| xcpretty -c
	set -o pipefail && xcodebuild clean build -workspace $(WORKSPACE) \
		-scheme 'UFO Example' \
		-sdk iphonesimulator -destination 'id=$(SIM_ID)'| xcpretty -c

example-static: static-lib
	cd Examples/UFO; set -o pipefail && xcodebuild clean build \
		-sdk iphonesimulator -destination 'id=$(SIM_ID)'| xcpretty -c

static-lib:
	bundle exec pod repo update >/dev/null
	bundle exec pod package ContentfulDeliveryAPI.podspec

	@cd Examples/UFO/Distribution; ./update.sh
	cd Examples; ./ship_it.sh

	rm -rf ContentfulDeliveryAPI-*/

kill_simulator:
	killall "Simulator" || true

test: kill_simulator really_clean
	set -x -o pipefail && xcodebuild test -workspace $(WORKSPACE) \
		-scheme 'ContentfulDeliveryAPI' -sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=iPhone 5s,OS=10.2'| xcpretty -c 
	kill_simulator	
	bundle exec pod lib coverage

lint:
	set -o pipefail && xcodebuild clean build -workspace $(WORKSPACE) -dry-run \
		-scheme ContentfulDeliveryAPI \
		-sdk iphonesimulator -destination 'id=$(SIM_ID)' clean build| \
		xcpretty -r json-compilation-database -o compile_commands.json
	oclint-json-compilation-database

doc:
	bundle exec pod lib docstats
