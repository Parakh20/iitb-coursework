#include <bits/stdc++.h>
using namespace std;

int main() {
    int n;
    cin >> n;
    vector<tuple<int, int, int>> ranges(n); // {start, end, index}
    for (int i = 0; i < n; ++i) {
        int x, y;
        cin >> x >> y;
        ranges[i] = {x, y, i};
    }

    sort(ranges.begin(), ranges.end()); // sort by start time

    priority_queue<pair<int, int>, vector<pair<int, int>>, greater<>> pq; // {end_time, room_number}
    int room_counter = 0;
    vector<int> result(n);

    for (auto &[start, end, idx] : ranges) {
        if (!pq.empty() && pq.top().first < start) {
            // Reuse existing room
            auto [old_end, room_no] = pq.top(); pq.pop();
            result[idx] = room_no;
            pq.emplace(end, room_no);
        } else {
            // Allocate new room
            ++room_counter;
            result[idx] = room_counter;
            pq.emplace(end, room_counter);
        }
    }

    cout << room_counter << "\n";
    for (int x : result) cout << x << " ";
    cout << "\n";

    return 0;
}
