# Over the years I've saved a spreadsheet of shows/episodes I've watched on streaming media
# This script munges them into a useable format consistent with those produced by other scripts.

s/, S[0-9]{2}.*//
s/: Seasons? [0-9].*//
s/: Series [0-9].*//
s/Collateral:.*/Collateral/
s/Heat of the Sun:.*/Heat of the Sun/
s/Inspector Alleyn Mysteries:.*/Inspector Alleyn Mysteries/
s/Jack Whitehall: Travels with My Father:.*/Jack Whitehall: Travels with My Father/
s/Marcella:.*/Marcella/
s/MI-5:.*/MI-5/
s/Midsomer Murders:.*/Midsomer Murders/
s/Monroe: Class of '76:.*/Monroe: Class of '76/
s/(My Next Guest Needs No Introduction With David Letterman: [^\:]*).*/\1/
s/(P.D. James: [^\:]*).*/\1/
s/Painted Lady:.*/Painted Lady/
s/Planet Earth II:.*/Planet Earth II/
s/Rough Diamond:.*/Rough Diamond/
s/Suspicion:.*/Suspicion/
s/TEDTalks:.*/TEDTalks/
s/The Grand:.*/The Grand/
s/The Guilty:.*/The Guilty/
s/The House of Cards Trilogy \(BBC\):.*/The House of Cards Trilogy (BBC)/
s/The Silence:.*/The Silence/
s/The State Within:.*/The State Within/
s/Tinker, Tailor, Soldier, Spy:.*/Tinker, Tailor, Soldier, Spy/
s/Wormwood:.*/Wormwood/
s/"/\\"/g
s/^/"/
s/$/"/
