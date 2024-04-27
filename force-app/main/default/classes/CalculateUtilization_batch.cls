public class CalculateUtilization_batch implements Database.Batchable<SObject>, database.stateful{
    // set to store assetids
    public set<id> AssetAndUtilizationIdset;
    public List<EOSedge_Utilization__c> assetList;
    
    public CalculateUtilization_batch(set<id> AssetAndUtilizationId){
        assetList = new list<EOSedge_Utilization__c>();
        AssetAndUtilizationIdset = new set<id>();
        AssetAndUtilizationIdset = AssetAndUtilizationId;
        system.debug('AssetAndUtilizationIdset: '+AssetAndUtilizationIdset);
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        string strQuery = 'select id, Asset__c, asset__r.Average_per_day_5_week__c, asset__r.Total_Acquisitions__c, asset__r.CreatedDate, CreatedDate, Acquisition_Lanes__c, Start_Time__c, Protocol_Name__c from EOSedge_Utilization__c where asset__c =:AssetAndUtilizationIdset';
        Database.QueryLocator qu = Database.getQueryLocator(strQuery);
        Database.QueryLocatorIterator it = qu.iterator();
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext context, List<EOSedge_Utilization__c> scope) {
        for(EOSedge_Utilization__c asst : scope){
            assetList.add(asst);
        }
    }
    
    public void finish(Database.BatchableContext context) {
        
        if(assetList.size()>0){
            UtilizationInsertClass();
        }else{
            system.debug('else runing');
            Id assetId;
            for(Id str : AssetAndUtilizationIdset){
                assetId = str;
            }
            
            Asset ass = new Asset();
            ass.Average_per_day_5_week__c = 0;
            ass.Average_Per_Week__c = 0; 
            ass.Average_days_week_system_in_use__c = 0;
            ass.Average_per_day_system_in_use__c = 0;
            ass.Average_Per_Month__c = 0;
            ass.Average_Per_Year__c = 0;
            ass.Full_Body__c = 0;
            ass.Other_Exam__c = 0;
            ass.Full_Spine__c = 0;
            ass.Lower_Limb__c = 0;
            ass.MicroDose_Exam__c = 0;
            ass.Biplane__c = 0;
            ass.Max_Per_Day__c = 0;
            ass.First_acquisition_date__c = null;
            ass.Last_acquisition_date__c = null;
            ass.Id = assetId;
            update ass;
        }
    }
    
    public void UtilizationInsertClass(){
        
        set<id>AssetIds = new set<id>();
        map<id, datetime> LatestStartDate = new map<id,datetime>();
        map<id, datetime> EarliestStartDate = new map<id,datetime>();
        Set<Date> uniqueDates = new Set<Date>();
        map<string,integer>FullBodyMap = new map<string,integer>();
        list<datetime> startDateList = new list<datetime>();
        double noofdays ;
        double noOfWeeks;
        double totalnumberofdaysconsidering5daysinweek;
        double Averageperday5perweek ;
        double Averageperweek;
        double noofoperatingdays;
        double Averageperdaysysteminuse;
        double TotalAcquisitions = 0 ;
        double averagePerMonth;
        double averagePerYear;
        double Body;
        double spine;
        double lowerLimb;
        double others;
        double Biplan;
        double microdose;
        double uniqueDAteSize;
        Datetime earliestDate;
        Datetime latestDate;
        Integer maxCount = 0;
        
        
        TotalAcquisitions = assetList[0].asset__r.Total_Acquisitions__c;
        
        //List<EOSedge_Utilization__c> eosList = new List<EOSedge_Utilization__c>();
        Map<Datetime, Integer> startTimeCounts = new Map<Datetime, Integer>();
        Id assetId = AssetList[0].asset__c;
        
        for(EOSedge_Utilization__c ec: AssetList){
            
            // Calculate Max per Day
            Date startDate = ec.Start_Time__c.date();  // Extract date portion
            Integer count = startTimeCounts.get(startDate);
            startTimeCounts.put(startDate, (count == null) ? 1 : count + 1);
            
            startDateList.add(ec.Start_Time__c);
            
            // Protocol Names
            if(ec.Protocol_Name__c != null){
                if(ec.Protocol_Name__c.equalsIgnoreCase('full body') || ec.Protocol_Name__c.equalsIgnoreCase('full spine') || ec.Protocol_Name__c.equalsIgnoreCase('lower limbs') || ec.Protocol_Name__c.containsIgnoreCase('micro dose')){
                    
                    if(ec.Protocol_Name__c.equalsIgnoreCase('full body')){
                        if(FullBodyMap.containsKey('full_body')){
                            FullBodyMap.put('full_body',FullBodyMap.get('full_body')+1);
                        }else{
                            FullBodyMap.put('full_body',1);
                        }
                        
                    }else if(ec.Protocol_Name__c.equalsIgnoreCase('full spine')){
                        if(FullBodyMap.containsKey('full_spine')){
                            FullBodyMap.put('full_spine',FullBodyMap.get('full_spine')+1);
                        }else{
                            FullBodyMap.put('full_spine',1);
                        }
                        
                    }else if(ec.Protocol_Name__c.equalsIgnoreCase('lower limbs')){
                        if(FullBodyMap.containsKey('lower_limbs')){
                            FullBodyMap.put('lower_limbs',FullBodyMap.get('lower_limbs')+1);
                        }else{
                            FullBodyMap.put('lower_limbs',1);
                        }
                        
                    }else if(ec.Protocol_Name__c.containsIgnoreCase('micro dose')){
                        if(FullBodyMap.containsKey('micro dose')){
                            FullBodyMap.put('micro dose',FullBodyMap.get('micro dose')+1);
                        }else{
                            FullBodyMap.put('micro dose',1);
                        }
                    }
                    
                }else{
                    if(!ec.Protocol_Name__c.equalsIgnoreCase('full body') && !ec.Protocol_Name__c.equalsIgnoreCase('full spine') && !ec.Protocol_Name__c.equalsIgnoreCase('lower limbs') && !ec.Protocol_Name__c.containsIgnoreCase('micro dose')){
                        if(FullBodyMap.containskey('Others')){
                            FullBodyMap.put('Others',FullBodyMap.get('Others')+1);
                        }else{
                            FullBodyMap.put('Others',1);
                        }
                    }
                }
            }   
            
            // Acquisition Lanes 
            if(ec.Acquisition_Lanes__c != null && ec.Acquisition_Lanes__c.equalsIgnoreCase('Biplan')){
                if(FullBodyMap.containsKey(ec.Acquisition_Lanes__c)){
                    FullBodyMap.put(ec.Acquisition_Lanes__c,FullBodyMap.get(ec.Acquisition_Lanes__c)+1);
                }else{
                    FullBodyMap.put(ec.Acquisition_Lanes__c,1) ;
                }
            }
        }
        
        // max count
        for (Datetime dt : startTimeCounts.keySet()) {
            maxCount = Math.max(maxCount, startTimeCounts.get(dt));
        }
        
        system.debug('FullBodyMap: '+FullBodyMap);
        
        for(string fbm : FullBodyMap.keySet()){
            
            if(fbm != null && fbm.equalsIgnoreCase('full_body')){
                body = (FullBodyMap.get(fbm)/TotalAcquisitions)*100;
            }
            if(fbm != null && fbm.equalsIgnoreCase('full_spine')){
                spine = (FullBodyMap.get(fbm)/TotalAcquisitions)*100;
            }
            if(fbm != null && fbm.equalsIgnoreCase('lower_limbs')){
                lowerLimb = (FullBodyMap.get(fbm)/TotalAcquisitions)*100;
            }
            if(fbm != null && fbm.containsIgnoreCase('micro dose')){
                microdose = (FullBodyMap.get(fbm)/TotalAcquisitions)*100;
            }
            if(fbm != null && fbm.EqualsIgnoreCase('Others')){
                others = (FullBodyMap.get('Others')/TotalAcquisitions)*100;
            }
            if(fbm != null && fbm.containsIgnoreCase('Biplan')){
                Biplan = (FullBodyMap.get(fbm)/TotalAcquisitions)*100;
            }
        }
        
        
        startDateList.sort();
        
        system.debug('startDateList: '+startDateList);
        system.debug('AssetList@@: '+AssetList);
        EarliestStartDate.put(assetId, startDateList[0]);
        LatestStartDate.put(assetId, startDateList[startDateList.size() - 1]);
        
        System.debug('EarliestStartDate:@@ ' + EarliestStartDate);
        System.debug('LatestStartDate:@@ ' + LatestStartDate);
        earliestDate = startDateList[0];
        latestDate = startDateList[startDateList.size() - 1];
        double differenceInDays = earliestDate.date().daysBetween(latestDate.date()) +1;
        noofdays = double.valueOf(differenceInDays);
        system.debug('noofdays@@: '+noofdays);
        for (EOSedge_Utilization__c eos : AssetList) {
            uniqueDates.add(eos.Start_Time__c.date()); 
        }
        
        
        
        noOfWeeks = (double) noofdays / 7;
        totalnumberofdaysconsidering5daysinweek = (noofdays * 5) / 7;
        Averageperday5perweek = TotalAcquisitions/totalnumberofdaysconsidering5daysinweek;
        Averageperweek = Averageperday5perweek * 5;
        uniqueDAteSize = (uniqueDates.size() / noofdays) * 7;
        system.debug('uniqueDAteSize: '+uniqueDAteSize);
        Averageperdaysysteminuse = (TotalAcquisitions/noofdays)*(7/uniqueDAteSize);
        averagePerMonth = (TotalAcquisitions/noofdays) * 365 / 12;
        
        System.debug('EarliestStartDate: ' + EarliestStartDate);
        System.debug('LatestStartDate: ' + LatestStartDate);
        system.debug('no of days: '+noofdays);
        system.debug('no of weeks(no_weeks): '+noOfWeeks);
        system.debug('totalnumberofdaysconsidering5daysinweek: '+totalnumberofdaysconsidering5daysinweek);
        system.debug('Averageperday5perweek: '+Averageperday5perweek);
        system.debug('Averageperweek: '+Averageperweek);
        system.debug('uniqueDAteSize: '+uniqueDAteSize);
        system.debug('Averageperdaysysteminuse: '+Averageperdaysysteminuse);
        
        Asset ass = new Asset();
        ass.Average_per_day_5_week__c = Averageperday5perweek;
        ass.Average_Per_Week__c = Averageperweek;
        ass.Average_days_week_system_in_use__c = uniqueDAteSize;
        ass.Average_per_day_system_in_use__c = Averageperdaysysteminuse;
        ass.Average_Per_Month__c = averagePerMonth;
        ass.Average_Per_Year__c = averagePerMonth*12;
        ass.Full_Body__c = body;
        ass.Other_Exam__c = others;
        ass.Full_Spine__c = spine;
        ass.Lower_Limb__c = lowerLimb;
        ass.MicroDose_Exam__c = microdose;
        ass.Biplane__c = Biplan;
        ass.Max_Per_Day__c = maxCount;
        ass.First_acquisition_date__c = earliestDate.date();
        ass.Last_acquisition_date__c = latestDate.date();
        ass.Id = assetId;
        
        update ass;
    }
    
}