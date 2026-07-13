# Kodi Sample Catalog

`Tests/KSPlayerTests/Resources/kodi-samples.json` catalogs the 43 Kodi samples used to exercise the project's codec, container, HDR, HDR10+, Dolby Vision, VP9, ProRes, and AV1 paths. The media itself is not committed yet: it is large, hosted by third parties, and includes collection and YouTube links that are not direct media URLs.

The catalog preserves Kodi's canonical links. Download only samples you are authorized to use, name each file with its `fileName` from the catalog, and place them in one directory. Then make small, stream-copied fixtures:

Windows:

```powershell
Tools/Trim-KodiSamples.ps1 -OriginalSamplesDirectory C:\path\to\originals -FixtureOutputDirectory Tests\KSPlayerTests\Resources\KodiFixtures
```

macOS/Linux:

```sh
Tools/trim-kodi-samples.sh /path/to/originals Tests/KSPlayerTests/Resources/KodiFixtures
```

The scripts need `ffmpeg`; the macOS/Linux script also needs `jq`. They skip catalog entries that are YouTube pages or collections. They keep the source streams and metadata intact, and write approximately three-second clips named `<id>-3s.<extension>`. Review the resulting files, then commit only the fixtures that are authorized for redistribution.

To run the opt-in playback smoke test on an Apple platform, point it to the generated fixture directory and select fixture IDs:

```sh
KSPLAYER_KODI_SAMPLES_DIRECTORY=Tests/KSPlayerTests/Resources/KodiFixtures \
KSPLAYER_KODI_SAMPLE_IDS=hdr10plus-iss-24,dv-mystery-box-p5 \
swift test --filter KodiSampleCatalogTests/testSelectedLocalKodiSamplesOpen
```

The smoke test opens the selected files with `KSMEPlayer`; it does not play their full duration. The normal test suite remains offline and does not download or stream third-party media.

Source: https://kodi.wiki/view/Samples
