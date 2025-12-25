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
        // Load samples in startup directory
        var loadSamples = { |path|
                PathName(path)
                    .entries
                    .select { |f| SoundFile.openRead(f.fullPath) != nil }
                    .collect { |f|
                        Buffer.read(s, f.fullPath);
                    };
            };
        d = Dictionary[];
        PathName("samples".resolveRelative)
            .entries
            .select { |f| f.isFolder }
            .do { |f|
                d[f.folderName.asSymbol] = loadSamples.(f.fullPath);
            };
        s.sync;
        "synthdefs.scd".loadRelative;
        s.sync;
    };
};
);

