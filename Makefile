XCB           = xcodebuild
CONFIGURATION = Release
XCBFLAGS      = -configuration $(CONFIGURATION)

.PHONY: dochtml docset

all: framework mac iphonelib iphone

framework:
	$(XCB) $(XCBFLAGS) -target AudioStreamer

mac:
	$(XCB) $(XCBFLAGS) -target 'Mac Streaming Player'

iphonelibios: 
	$(XCB) $(XCBFLAGS) -sdk iphoneos -target 'libAudioStreamer'

iphonelibsim: 
	$(XCB) $(XCBFLAGS) -sdk iphonesimulator -target 'libAudioStreamer'

iphonelib: iphonelibios iphonelibsim
	rm -rf build/Release-fat 
	mkdir build/Release-fat
	lipo build/Release-iphoneos/libAudioStreamer.a build/Release-iphonesimulator/libAudioStreamer.a \
		-create -output build/Release-fat/libAudioStreamer.a
	cp -rf build/Release-iphoneos/include build/Release-fat

iphone: XCBFLAGS += -sdk iphoneos
iphone:
	$(XCB) $(XCBFLAGS) -target 'iPhone Streaming Player'

dochtml:
	appledoc --project-name AudioStreamer --project-company ' ' \
		--company-id ' ' --no-repeat-first-par -o dochtml \
		--no-create-docset --explicit-crossref --ignore AudioStreamer.m \
		--ignore ASPlaylist.m --ignore iOSStreamer.m AudioStreamer

docset:
	appledoc --project-name AudioStreamer --project-company ' ' \
		--company-id ' ' --no-repeat-first-par -o docset \
		--docset-install-path docset --explicit-crossref \
		--ignore AudioStreamer.m --ignore ASPlaylist.m \
		--ignore iOSStreamer.m AudioStreamer

clean:
	$(XCB) clean
	rm -rf build
