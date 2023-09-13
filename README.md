Things I would clean up with BA or team:
1)  There are 21 'InitGame' entries and 20 'ShutdownGame' entries.  
    The matching shutdown game would be on line 97 but that seems cut.  That line starts with 26 and is followed by MM:SS -------... 
    I would expect it to be something like:
        26:10 ShutdownGame:
        26:10 ------------------------------------------------------------
        0:00 ------------------------------------------------------------
        init game

        instead of
        26  0:00 ------------------------------------------------------------
        0:00 InitGame:
  The missing ShutdownGame + -------- could indicate a corrupted log, server failure, well... that's relevant to at least be brought on the daily.
  
  It seems that we always have at least the initial ---------------- and InitGame following.  I prefered to stop on ------------ because it happens first and also InitGame has information, if we need to parse InitGame info, having stoped before reading InitGame allow us to keep InitGame inside the next match read without any further manipulation.
  
2) I played quake 1 and 2 at that time, but I did not had good connection so I never played quake 3 arena, that means that I don't really understand why some games init 0:00 and others doesn't.  I'm also pretty bad at fps, sorry.

3) The players have an ID, but we are printing names.  I decided to keep the last used name, but I would rather store some form of ID.
   <world> id is 1022.  I'm assuming this is hardcoded for them.  Could not be the case... I'm assuming it is.

4) The MODs have that #ifdef and there's no entry on the log for nothing inside ifdef nor MOD_GRAPPLE, so I have no means of knowing if we're on missionpack or not (changing the relation of MOD id to mod description)
   I also would avoid it because it complicates a tiny bit, you need the mode to parse a log, so... I kept all and would not return them as options according to the flag for whoever needs them.

5) There's no rule for self killing.  It definetively shouldn't increase your score.  Should it decreased it like a <world> kill?  I think it should.  I also counted that on total_kills because it is.

6) I understand that we're always returning the score of the players, and when asked on the PLUS section, we add the kills_by_means log.

7) I would like to address the quote about truth only being on the code.  That's not entirely true. 
 Often there are many interactions outside the code that come from database triggers, reroutings, external sources, other codebases and even people with practices.  
 Idealy would be all on documentation, but well, it is a sum of all.  Now, in defense of Robert, I try to document these things on code because it is the main source of truth... 
 But as the brazilian comic artist Andre Dahmer once wrote "If truth were an object it would be modeling clay".

Decisions

I decided to keep the structure as simple as possible while addressing and discussing some of the concerns that I had.
As the classes are small, I thought that fitting on only one file would be easier to read and to write.
Each class could be a file and the code outside classes a lib that would be called by a rake task, or even a controller inside admin.