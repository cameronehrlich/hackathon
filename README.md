hackathon
=========

Acoustic Detection
By, Cameron Ehrlich and Brian Freese


Our project aims to expand your iOS device's touch screen to include whatever (hard) surface it is resting on by utilizing acoustic
queues from the surface instead of just the capacitative touch screen.  The original application of this we
had in mind was turning a desk into a drum set (Magic Drums!) by calibrating certain "zones", such that when tapped, they produce a sound
unique to that spot; which from there could be turned into a "DrumHero"-esque game.  Other applications we considered were
a trivia game in which the first person to tap in their "zone" on the table gets to answer, or once we fine-tune the
detection algorithm, could even be used as a portable piano or synthesizer that isn't confined to a 4-inch touch screen! (We know this will be tricky!)
The main inspiration for this was a video showcasing students' work on using a single accelorometer to create a tap-sensitive
chalkboard (http://www.youtube.com/watch?v=ZoAslMiukAQ -- https://docs.google.com/file/d/0B1oRgy6mXOKaazNqX3g1dW1LUVU/edit?pli=1), and our detection algorithm is based on one form of theirs -- although we
tweaked ours significantly to account for the buffering and framing of audio input data).

We thought of this idea a while ago, but only decided on this project about 5 minutes before arriving at the Hackathon, and started from 
scratch with researching the paper linked in the video, so there are many areas that have room for improvement. Our detection algorithm is still immature
and taps to the same spot may produce somewhat different data, depending on the character of the strike.  However, 
placement of the tap is still most significant, and given a few calibrated samples, the application will correctly 
choose the sample whose origin was most close to an input tap.  The UI is mostly non-existent as we spent most of the night 
working with Core Audio to collect the raw acoustic input from the phone's microphone, which proved to be one of the 
most difficult aspects. We plan on adding many optimizations to the algorithm, both in speed and accuracy.  Currently, we
take in buffers of raw audio data, and compare one buffer full of a calibrated sample against one buffer of the raw input,
lining them up based on their maximum value (indicating a tap).  The comparison is a cross-correlation function, which gives a
rating to the match based on a function of the two vectors, and their means and standard deviations.  We considered using
FFT to use frequency domain data as opposed to magnitude (which we use now), but researching a bit, we found it did not
significantly improve the other students' attempt much, and so deffered that for later attempts.  We also plan on trying 
different filters, experimenting with buffer size and how many buffers we use to generate a rating, and fine-tuning how we put
the two vectors into phase with each other (this is one aspect which significantly influenced the correlation rating).

What makes this project cool:
- We only use one audio source!
- Realtime signal differentiation!
- We didn't use any prebuilt DSP libraries or frameworks.
- It's pretty darn accurate as it is, even though we have many ways to improve it still.
- Got to this point in less than 18 hours.
- This is easily the most complex thing either of us has ever taken on.
- There are SO many possible applications for this! (Once all the kinks get worked out, that is)
