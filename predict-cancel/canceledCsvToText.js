const csvtojson = require('csvtojson')

const csv = require('fs').readFileSync('canceled.csv').toString();

const users = { /* id: [ word, word, word ] */ };
const userLastType = { /* userId: { type: ..., id } */ };

function getMedian(args) {
  if (!args.length) {return 0};
  var numbers = args.slice(0).sort((a,b) => a - b);
  var middle = Math.floor(numbers.length / 2);
  var isEven = numbers.length % 2 === 0;
  return isEven ? (numbers[middle] + numbers[middle - 1]) / 2 : numbers[middle];
}

csvtojson({delimiter:';',noheader:false})
.fromString(csv)
.on('csv',(csvRow)=>{ // this func will be called 3 times
  const [ userId, readStatus, type, id, ep, title ] = csvRow;

  if (typeof users[userId] === 'undefined') {
    users[userId] = [ 'B' ]; // begin
  }
  // grabbing last type info
  const lastType = userLastType[userId];
  // pushing new info
  if (type === 'FILM') {
    users[userId].push('F');
    //users[userId].push(id);
  } else {
    if (!lastType ||
         lastType.type === 'FILM' ||
         lastType.id !== id) {
      // l'utilisateur vient de lire un film ou une autre serie
      // on reprend du départ
      users[userId].push('S')
    }
    users[userId].push(ep);
  }
  if (readStatus === 'SKIP') {
    users[userId].push('K');
  }
  // saving last type.
  userLastType[userId] = { type: type, id: id };
})
.on('done',()=>{
  let maxLength = 0;
  const table = [];

  for (i in users) {
    users[i].push('X');
    const length =  users[i].join('').length;
    //if (length > 64) continue;
    table.push(users[i].join(''))
    maxLength = Math.max(maxLength, length)
  }

  //-- data prete, on imprime :
  let result = "";
  table.forEach(l=>{
    result +=  l + '.'.repeat(Math.max(10, 64 - l.length)); // + "\n";
  })
  console.log(result.toLowerCase());
})
