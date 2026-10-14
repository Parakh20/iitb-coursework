class Solution {
public:
    bool canmakebouqets(vector<int>& bloomDay, int m, int k, int day){
         int bouqets=0, flowers=0;
         for(int bloom : bloomDay){
            if(bloom<=day){
                flowers++;
                if(flowers==k){
                    bouqets++;
                    flowers=0;
                }
            }
            else{
                flowers=0;
            }
         }
            return bouqets>=m;
    }

    int minDays(vector<int>& bloomDay, int m, int k) {
        long long totalflowers = (long long)m*k;
        if(totalflowers > bloomDay.size()) return -1;
        int low = *min_element(bloomDay.begin(), bloomDay.end());
        int high = *max_element(bloomDay.begin(), bloomDay.end());
        int ans =-1;
        while(low<=high){
            int mid = low + (high-low)/2;
            if(canmakebouqets(bloomDay, m,  k, mid)){
                ans =mid;
                high = mid-1;
            }
            else{
                low = mid+1;
            }
        }
        return ans;
    }
};