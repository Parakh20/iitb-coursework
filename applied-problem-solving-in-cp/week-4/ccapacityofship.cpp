class Solution {
public:
    int shipWithinDays(vector<int>& weights, int days) {
        int low = *max_element(weights.begin(), weights.end());
        int high = accumulate(weights.begin(), weights.end(), 0);
        int ans = high;
        while(low<=high){
            int mid = low + (high-low)/2;
            int sum=0;
            int day=1;
            for(int w: weights){
                if(sum+w>mid){
                    day++;
                    sum=0;
                    
                }
                sum+=w;
            }
            if (day <= days) {
                ans = mid;
                high = mid - 1;
            } else {
                low = mid + 1;
            }
            
        }
        return ans;
    }
};