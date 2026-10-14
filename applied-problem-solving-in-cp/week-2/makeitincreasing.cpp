#include <iostream>
#include <vector>
using namespace std;

int min_operations_to_make_increasing(vector<int>& a) {
    int n = a.size();
    int operations = 0;

    // Work from the end to the beginning
    for (int i = n - 2; i >= 0; --i) {
        // If the current element is already less than the next one, it's fine
        if (a[i] < a[i + 1]) continue;

        int original = a[i];
        int count = 0;

        // Keep dividing a[i] by 2 until it's less than a[i+1] or becomes 0
        while (a[i] >= a[i + 1] && a[i] > 0) {
            a[i] /= 2;
            ++count;
        }

        // If it became 0 and still not less than a[i+1], it's impossible
        if (a[i] >= a[i + 1]) return -1;

        operations += count;
    }

    return operations;
}

int main() {
    int t;
    cin >> t;
    while (t--) {
        int n;
        cin >> n;
        vector<int> a(n);
        for (int i = 0; i < n; ++i) {
            cin >> a[i];
        }

        cout << min_operations_to_make_increasing(a) << endl;
    }
    return 0;
}
