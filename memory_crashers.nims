import std/os

# Common settings
switch("path", projectDir() / "src")
--mm:orc

when defined(emscripten):
  --define:GraphicsApiOpenGlEs2
  --define:NaylibWebResources
  switch("define", "NaylibWebResourcesPath=resources")
  --os:linux
  --cpu:wasm32
  --cc:clang
  when buildOS == "windows":
    --clang.exe:emcc.bat
    --clang.linkerexe:emcc.bat
    --clang.cpp.exe:emcc.bat
    --clang.cpp.linkerexe:emcc.bat
  else:
    --clang.exe:emcc
    --clang.linkerexe:emcc
    --clang.cpp.exe:emcc
    --clang.cpp.linkerexe:emcc
  --threads:on
  --panics:on
  --define:noSignalHandler
  --passL:"-o public/index.html"
  --passL:"--shell-file minshell.html"
  --passL:"-sALLOW_MEMORY_GROWTH=1"
