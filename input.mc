int main() {
    int i;
    int sum;
    sum = 0;
    for (i = 0; i < 5; i = i + 1) {
        if (i % 2 == 0) continue;
        sum = sum + i;
    }
    while (sum < 20) {
        sum = sum + 1;
    }
    if (sum > 20) {
        return 1;
    } else {
        return 0;
    }
}