#include <bits/stdc++.h>
using namespace std;

struct Query {
    int l, r, idx;
};

int block_size;

bool compare(Query a, Query b) {
    if (a.l / block_size != b.l / block_size)
        return a.l / block_size < b.l / block_size;
    return (a.l / block_size & 1) ? (a.r < b.r) : (a.r > b.r);
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n, q;
    cin >> n >> q;
    
    vector<int> arr(n);
    set<int> unique_vals;
    
    for (int i = 0; i < n; i++) {
        cin >> arr[i];
        unique_vals.insert(arr[i]);
    }
    
    // Coordinate compression
    map<int, int> compress;
    int idx = 0;
    for (int val : unique_vals) {
        compress[val] = idx++;
    }
    
    for (int i = 0; i < n; i++) {
        arr[i] = compress[arr[i]];
    }
    
    block_size = sqrt(n);
    
    vector<Query> queries(q);
    for (int i = 0; i < q; i++) {
        cin >> queries[i].l >> queries[i].r;
        queries[i].l--; queries[i].r--;
        queries[i].idx = i;
    }
    
    sort(queries.begin(), queries.end(), compare);
    
    vector<int> freq(unique_vals.size(), 0);
    vector<int> answers(q);
    int current_l = 0, current_r = -1;
    int current_answer = 0;
    
    for (auto query : queries) {
        int l = query.l, r = query.r;
        
        while (current_r < r) {
            current_r++;
            if (freq[arr[current_r]] == 0) {
                current_answer++;
            }
            freq[arr[current_r]]++;
        }
        
        while (current_r > r) {
            freq[arr[current_r]]--;
            if (freq[arr[current_r]] == 0) {
                current_answer--;
            }
            current_r--;
        }
        
        while (current_l > l) {
            current_l--;
            if (freq[arr[current_l]] == 0) {
                current_answer++;
            }
            freq[arr[current_l]]++;
        }
        
        while (current_l < l) {
            freq[arr[current_l]]--;
            if (freq[arr[current_l]] == 0) {
                current_answer--;
            }
            current_l++;
        }
        
        answers[query.idx] = current_answer;
    }
    
    for (int i = 0; i < q; i++) {
        cout << answers[i] << "\n";
    }
    
    return 0;
}
