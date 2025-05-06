import { Address, beginCell, Cell, Slice } from "@ton/core";
import Prando from "prando";
import { Builder } from "@ton/core";



export function createRandomGenerator(seed: bigint) {
    const generator = new Prando(seed.toString());
    
    const nextBytes = (n: number) => {
        const hexString = generator.nextString(n * 2, "0123456789abcdef");
        return Buffer.from(hexString, "hex");
    };

    function generateCell(
        maxDepth: number,
        maxRefsPerCell: number,
        bitsInRootCell: number,
        totalCells: number
    ) {
        if (totalCells > 0) {
            totalCells--;
        }
        
        const buildCell = (refsPerCell: number, depth: number) => {
            let builder = beginCell();
            builder.storeBuffer(nextBytes(Math.floor(bitsInRootCell / 8)));
            
            let refsAdded = 0;
            if(depth > 0) {
                while(totalCells > 0 && refsAdded < refsPerCell) {
                    totalCells--;
                    const ref = buildCell(refsPerCell, depth - 1);
                    builder.storeRef(ref);
                    refsAdded++;
                }
            }
            
            return builder.endCell();
        }
        
        let rootBuilder = beginCell();
        rootBuilder.storeBuffer(nextBytes(Math.floor(bitsInRootCell / 8)));
        
        for(let i = 0; i < maxRefsPerCell; i++) {
            if(totalCells > 0) {
                totalCells--;
                const ref = buildCell(maxRefsPerCell, maxDepth - 1);
                rootBuilder.storeRef(ref);
            }
        }
        
        if(totalCells > 0) {
            console.error(`Total cells not used, ${totalCells} cells left`);
        }
        
        return rootBuilder.endCell();
    }
    
    
    return {
        next: generator.next.bind(generator),
        nextInt: generator.nextInt.bind(generator),
        nextBoolean: generator.nextBoolean.bind(generator),
        nextString: generator.nextString.bind(generator),
        nextChar: generator.nextChar.bind(generator),
        nextArrayItem: generator.nextArrayItem.bind(generator),
        reset: generator.reset.bind(generator),
        skip: generator.skip.bind(generator),
        nextBytes,
        nextAddress: (workchain: number) => {
            const buffer = nextBytes(32); // Ton address hash part is 32 bytes
            return new Address(workchain, buffer);
        },
        nextCell: function(maxDepth: number = 1, maxRefsPerCell: number = 0, bitsInRootCell: number = 1023, totalCells: number = 1): Cell {
            return generateCell(maxDepth, maxRefsPerCell, bitsInRootCell, totalCells);
        },
        nextSlice: function(maxDepth: number = 1, maxRefsPerCell: number = 0, bitsInRootCell: number = 1023, totalCells: number = 1): Slice {
            return generateCell(maxDepth, maxRefsPerCell, bitsInRootCell, totalCells).beginParse();
        },
        nextBuilder: function(maxDepth: number = 1, maxRefsPerCell: number = 0, bitsInRootCell: number = 1023, totalCells: number = 1): Builder {
            return generateCell(maxDepth, maxRefsPerCell, bitsInRootCell, totalCells).asBuilder();
        }
    };
}

async function main() {
    const generator = createRandomGenerator(BigInt(1234567890));
    
    // Создаем клетку с дефолтными значениями
    console.log("=== Клетка по умолчанию ===");
    const defaultCell = generator.nextCell();
    console.log("Количество ссылок:", defaultCell.refs.length);
    console.log("Количество бит:", defaultCell.bits.length);
    
    // Создаем клетку с указанными параметрами
    console.log("\n=== Клетка с параметрами ===");
    const customCell = generator.nextCell(3, 2, 500, 10);
    console.log("Количество ссылок:", customCell.refs.length);
    console.log("Количество бит:", customCell.bits.length);
    
    console.log("\n=== Адрес ===");
    console.log(generator.nextAddress(0).toString());
}

if (require.main === module) {
    void main();
}