// for staging env

function gen() {
    
    let token1 = {
        "name": "Only #1",
        "description": "Only for the one",
        "image": "ifps://QmYqTNytToksyoJhhnccDfu48EbCoJ7d9ya1uCv1oDNhaM/token1.webp",
    };

    let token2 = {
        "name": "Only #2", 
        "description": "Only for the one",
        "image": "ifps://QmYqTNytToksyoJhhnccDfu48EbCoJ7d9ya1uCv1oDNhaM/token2.webp",
    };

    let token3 = {
        "name": "Only #3",
        "description": "Only for the one",
        "image": "ifps://QmYqTNytToksyoJhhnccDfu48EbCoJ7d9ya1uCv1oDNhaM/token3.webp",
    };

    console.log(`token1 json : ${JSON.stringify(token1)}`);
    console.log(`token2 json : ${JSON.stringify(token2)}`);
    console.log(`token3 json : ${JSON.stringify(token3)}`);
}

gen();