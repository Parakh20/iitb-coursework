#include <iostream>
using namespace std;

int main() {
    long long l, r;
    cin >> l >> r;

    // Since (r - l + 1) is guaranteed to be even, we can always pair
    cout << "YES\n";
    for (long long i = l; i <= r; i += 2) {
        cout << i << " " << i + 1 << "\n";
    }

    return 0;
}
