# Spiderpasta_4.x

Port of Pasta MSET to Spider entrypoint

To be loaded with Spider3DSTools. I use the version on DUKE web site (search for it on GBATemp)

Respect to the MSET version the first stage have been removed because it's performed by the loadcode.bin on the web server (loadcode4.bin version since this is for 4.x)

The code hangs (doesn't crash, it hangs forever) calling nn__gxlow__CTR__CmdReqQueueTx__TryEnqueue. I thought it was an error in finding the function offset in memory, but from CakesFW code I found it uses the same.

Don't know if I'll try to fix this now that CakesFW is out.

getting this to work will make porting to 9.X very simple (it only needs to change some addresses).

The weird thing I found is that using spider 17567 on 4.x makes GPUHAX not working. Rop gadgets in FCRAM are valid, so it must be some handle or VA that needs a fix.

Hope someone find this useful at least for studying purposes. 
