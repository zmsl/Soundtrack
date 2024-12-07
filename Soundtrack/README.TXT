Quick Setup

NOTE: MyTracks.lua GENERATION PROCESS HAS CHANGED 12/5/2022. You no longer need to copy MyTracks.lua to the Soundtrack folder,
and you don't need to install java or python to run the tools. See Step 3 in the readme below if you have generated a library
before.

While the new GenerateMyLibrary.ps1 and GenerateMyLibrary.command scripts don't require dependencies (Python or Java) they are slower,
so if you have a very large music library, you may want to use the Legacy Library Generation method instead.

1. Locate the folder named SoundtrackMusic in the Addons folder.
   (World of Warcraft\_retail\Interface\AddOns\SoundtrackMusic)

2. Copy your mp3s to that folder, and close WoW if it's already open. 
   Files added while WoW is running won't be noticed until you restart it.
   You can organize your music into subfolders, e.g. 
    \SoundtrackMusic\Lord of the Rings\
    \SoundtrackMusic\Pokemon\
    \SoundtrackMusic\Public Enemy\
    and so on.

3. To make your mp3s available in the game:
    a. Windows: Run GenerateMyLibrary.ps1 (Right click -> Run with Powershell)
    b. Mac/Linux: Run GenerateMyLibrary.bash (In terminal, cd to your SoundtrackMusic directory then run "bash GenerateMyLibrary.bash").

    You should now have a MyTracks.lua file in your SoundtrackMusic directory. If so then you are good to go!

    If it fails for any reason, you can try to use one of the legacy methods below to generate your library.


Legacy Library Generation:

There are two additional ways you can generate the MyTracks.lua file if the above method fails.

Option 1. Make sure you have java installed, then open SoundtrackMusic/LegacyLibraryGeneration/MusicManager.jar.
    a. If the UI doesnt open when you double click the MusicManager.jar, you can open it via command line if your
        working directory is SoundtrackMusic/LegacyLibraryGeneration and you run "java -jar MusicManager.jar" from powershell or cmd.
    b. Once the UI loads, click the Generate Library button (second from the right).

Option 2. Make sure you have Python 2.7 installed, then run SoundtrackMusic/LegacyLibraryGeneration/GenerateMyLibrary.py
