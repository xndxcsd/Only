// for staging env

function gen() : string {
    
    let obj = {
        "name": "Only",
        "description": "Only for the one",
        "image": "ifps://QmaS2PTm6AMsfCivXcoqkz6dEXeQSwkginDdytVDukwTT3/token0.webp",
    };

    return JSON.stringify(obj);
}

console.log(gen());