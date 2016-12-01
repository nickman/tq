package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class TqQueryBatches {

    private List<TqstubsObj> functionReturn;
    private Integer threadmod;
    private Integer rowlimit;
    private Integer threadcount;
    private Integer bucketsize;

    public List<TqstubsObj> getFunctionReturn() {
        return this.functionReturn;
    }

    public void setFunctionReturn(List<TqstubsObj> functionReturn) {
        this.functionReturn = functionReturn;
    }

    public Integer getThreadmod() {
        return this.threadmod;
    }

    public void setThreadmod(Integer threadmod) {
        this.threadmod = threadmod;
    }

    public Integer getRowlimit() {
        return this.rowlimit;
    }

    public void setRowlimit(Integer rowlimit) {
        this.rowlimit = rowlimit;
    }

    public Integer getThreadcount() {
        return this.threadcount;
    }

    public void setThreadcount(Integer threadcount) {
        this.threadcount = threadcount;
    }

    public Integer getBucketsize() {
        return this.bucketsize;
    }

    public void setBucketsize(Integer bucketsize) {
        this.bucketsize = bucketsize;
    }


}
