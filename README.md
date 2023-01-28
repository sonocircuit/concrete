# concrète

virtual tape explorations for norns. ***highly*** inspired by morphogene. not a clone.

very *very* WIP here... subject to many changes... many features still not working yet.

----
### quickstart

go to params > reel > save&load to load audio (48kHz, mono) if stereo, left channel will be loaded into buffer.

norns UI:

- **K1** hold: shift
- **ENC1**: change page

**page 1: tape**

- **K2**: change focus [playback / splices]

  ***playback:***
  - **K2**: toggle playback / if rec on then rec off
  - **K1** + **K2**: toggle rec --> rec modes under params > reel > recording

  - **ENC2**: rec level
  - **ENC3**: overdub level

  ***splices:***
  - **K2**: add splice
  - **K1** + **K2**: remove splice
  
  - **ENC3**: scrub playhead
  - **ENC3**: select active splice
  
  - **K1** + **ENC2**: move start marker of active splice
  - **K1** + **ENC3**: move end marker of active splice

**page 2: essai**

- **K2**: change focus [morph, size / varispeed, slide]

  ***moprh, size:***
  - **K2**: temp max. morph
  - **K1** + **K2**: freeze randomized values (morph > 75)

  - **ENC2**: morph amount
  - **ENC3**: loop size

  ***varispeed, slide:***
  - **K2**: toggle playback direction
  - **K1** + **K2**: speed envelope (under construction)
  
  - **ENC2**: playback speed 
  - **K1** + **ENC2**: clamp to scale values --> change scale in params
  - **ENC3**: slide position

