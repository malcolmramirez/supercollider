(
s.reboot { // server options are only updated on reboot
	// configure the sound server: here you could add hardware specific options
	// see http://doc.sccode.org/Classes/ServerOptions.html
    s.options.inDevice_("MacBook Pro Microphone");
    s.options.outDevice_("blackhole+phones");
    s.options.sampleRate = 44100;
    s.options.numBuffers = 1024 * 4;
	s.latency = 0.1; // increase this if you get "late" messages
    
    // Safety settings
    s.options.safetyClipThreshold = 1;

    // Load samples
    s.waitForBoot {
        var loadSamples = { |path|
                PathName(path)
                    .entries
                    .select { |f| SoundFile.openRead(f.fullPath) != nil }
                    .collect { |f|
                        Buffer.read(s, f.fullPath);
                    };
            };
        d = Dictionary[];

        // load samples
        PathName("samples".resolveRelative)
            .entries
            .select { |f| f.isFolder }
            .do { |f|
                d[f.folderName.asSymbol] = loadSamples.(f.fullPath);
            };

        // load signals
        d[\sigs] = [
            // sin
            Buffer.loadCollection(s, Signal.sineFill(s.sampleRate, [1.0]))
        ];

        // load synthdefs
        "synthdefs.scd".loadRelative;
        s.sync;
    };
};
);

