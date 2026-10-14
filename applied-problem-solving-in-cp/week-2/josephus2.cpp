#include <bits/stdc++.h>
using namespace std;


// Function to print the order in which children are removed
void solve(int N, int K)
{
    // 2D array to store ranges of size sqrt(N)
    vector<vector<int> > arr;

    int root = sqrt(N);
    int row = 0, col = 0, count = 0;

    // Construct the 2D vector arr
    vector<int> vec;
    for (int i = 1; i <= N; i++) {
        if (count > root) {
            count = 0;
            arr.push_back(vec);
            vec.clear();
        }
        vec.push_back(i);
        count++;
    }
    if (!vec.empty())
        arr.push_back(vec);

    // Iterate till we have removed all the children
    for (int i = 0; i < N; i++) {
        // Fnd the position of the element to be removed
        int j = K % (N - i);

        // Make jumps till we reach the position of the
        // element to be removed
        while (j) {
            // If we can jump j elements in the current row,
            // we jump to that column
            if (col + j < arr[row].size()) {
                col += j;
                j = 0;
            }
            // If we cannot jump j elements, we jump over
            // all the elements in the current row and move
            // to the next row
            else {
                j -= arr[row].size() - col;
                col = 0;
                row++;
            }
            // If all the elements are traversed, we start
            // from the first row again
            if (row >= arr.size())
                row = 0;
        }

        // While the current row has lesser columns, move to
        // the next row
        while (arr[row].size() <= col) {
            col = 0;
            row++;
            if (row >= arr.size())
                row = 0;
        }
        cout << arr[row][col] << " ";
        if (i != N - 1) {
            // Remove the student from the current row
            arr[row].erase(arr[row].begin() + col);
            while (arr[row].size() <= col) {
                col = 0;
                row++;
                if (row >= arr.size())
                    row = 0;
            }
        }
    }
}

int main()
{
    // Sample Input
    int N, K;
    cin >> N >> K;

    solve(N, K);

    return 0;
}