//OPIS: Sanity check za miniC gramatiku

int f(int x) {
    int y;
    return x + 2 - y;
}

unsigned f2() {
    return 2u;
}

unsigned ff(unsigned x) {
    unsigned y;
    return x + f2() - y;
}

int main() {
    int j;
    int b;
    int aa;
    int bb;
    int c;
    int d;
    unsigned u;
    unsigned w;
    unsigned uu;
    unsigned ww;

    //poziv funkcije
    j = f(3);
   
    //if iskaz sa else delom
    if (j < b)  //1
        j = 1;
    else
        j = -2;

    if (j + c == b + d - 4) //2
        j = 1;
    else
        j = 2;

    if (u == w) {   //3
        u = ff(1u);
        j = f(11);
    }
    else {
        w = 2u;
    }
    if (j + c == b - d - -4) {  //4
        j = 1;
    }
    else
        j = 2;
    j = f(42);

    if (j + (aa-c) - d < b + (bb-j))    //5
        uu = w-u+uu;
    else
        d = aa+bb-c;

    //if iskaz bez else dela
    if (j < b)  //6
        j = 1;

    if (j + c == b - +4)    //7
        j = 1;
}

