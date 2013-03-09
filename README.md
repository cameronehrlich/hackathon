hackathon
=========

Acoustic detection


Our project aims to expand your iPhone touch screen to encompass whatever (hard) surface it is resting on using acoustic
queues from the surface instead of just the capacitative touch screen on the phone.  The original application of this we
had in mind was turning a desk into a drum set by calibrating certain spots, such that when tapped, they produce a sound
unique to that spot; which from there could be turned into a "DrumHero"-esque game.  Other applications we considered were
a trivia game in which the first person to tap in front of them on the table gets to answer, or once we fine-tune the
detection algorithm, could even be used as a portable piano or synthesizer that isn't confined to a 4-inch touch screen.
The main inspiration for this was a video showcasing students' work on a touch-sensitive chalkboard
(http://www.youtube.com/watch?v=ZoAslMiukAQ), and our detection algorithm is based on one form of theirs (though
tweaked significantly to account for the buffering and framing of acoustic input data).

At this point our detection algorithm is still immature and taps to the same spot may produce somewhat different data, 
depending on the character of the strike.  However, placement of the tap is still most significant, and given a few
calibrated samples, the application will correctly choose the sample whose origin was most close to an input tap.  The UI
is mostly non-existent as we spent most of the night learning how to interpret and use Core Audio for the raw acoustic 
input from the phone's microphone, which proved to be the most difficult aspect. Given some more time and sleep, this app 
could well be one of the best looking, best sounding, and best hearing apps on the market.
