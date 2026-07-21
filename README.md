# BitSoup

BitSoup is a Vintage Story server implementation written from scratch in MASM assembly.

It is not a wrapper around the official server. There is no C# server hiding behind it doing the actual work. I am implementing the protocol, networking, world state, and everything else directly in x86-64 assembly.

Yes, on purpose.

## Why?

Modern server software has accumulated a lot of luxuries.

Garbage collection. Type safety. Bounds checking. Standard libraries. Useful error messages. Variables that stay meaningful for more than six instructions.

BitSoup gets rid of all that.

Every byte is managed by hand. Every allocation is intentional. Every register has a purpose, or at least had one when I wrote it. There is nothing standing between the server and the hardware except several thousand lines of assembly and my increasingly loose understanding of them.

There is no real need for a Vintage Story server written in assembly. I thought it would be funny to see if I could get a client to connect.

It connected.

So now I have to keep going.

## The goal

I want BitSoup to become an actual playable Vintage Story server.

Not necessarily a useful one. It is not meant to replace the official server, fix the community, change hosting forever, or justify the amount of time already spent on it.

I just want to finish it, join it, place a block, and know that an unreasonable number of `mov` instructions made that possible.

Eventually, BitSoup should:

- Accept real Vintage Story clients
- Manage multiple connected players
- Load and save worlds
- Handle blocks, entities, and inventories
- Generate terrain
- Implement enough of the game to actually play
- Keep working after the debugger is closed

The last one may take a while.

## Current status

It does things.

The client connects. Packets arrive. Other packets leave. Some of them are even the right packets.

I am currently about 1,200 lines into assembly and have reached the point where adding a small feature means scrolling past decisions made by a different version of myself several hours ago.

There are missing features, crashes, incorrect assumptions, and at least one part of the server that works every time despite having no obvious reason to.

I am leaving that part alone.

## Performance

BitSoup has no garbage collector, managed runtime, reflection, or unnecessary abstraction.

It is just the CPU, the operating system, and me asking both of them to be patient.

This should make it extremely fast eventually. Right now it is already very fast at the things it knows how to do, mainly because it does not know how to do very many things.

## Building

BitSoup targets Windows and is built with MASM.

Proper build instructions will be added when I remember which exact sequence of commands currently produces the working executable.

If it builds on the first try, you may have done something wrong.

## Contributing

Contributions are welcome, although I am not sure why you would do that to yourself.

The core server should remain in assembly. Replacing difficult parts with C or C++ would make everything much easier, but unfortunately I know that now and have chosen to continue anyway.

Please comment anything particularly clever. I am going to have to read it at 2 AM eventually.

## FAQ

### Is this serious?

I am genuinely writing it and I genuinely want it to work.

### Is it a joke?

It was funnier about 1,200 lines ago.

### Why MASM?

I wanted complete control over memory and execution.

I have it now.

### Why not use C, C++, Rust, or C#?

Because then I would just be writing a server.

### Will it support mods?

Eventually, maybe.

Right now I would like it to support itself. 

### Is it production-ready?

No.

You are welcome to ignore that, but please do not bring me the resulting world file.

### Are you sane?

Yes.

I am sane. I swear.

I just need to finish the packet decoder.

## Disclaimer

BitSoup is an unofficial project and is not affiliated with Anego Studios.

It is provided without warranty. It may crash, disconnect clients, corrupt worlds, or continue running in a state that would honestly be worse than crashing.

Make backups.

I am going back to the packet decoder.
