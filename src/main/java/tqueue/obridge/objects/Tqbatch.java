package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class Tqbatch {

    private Integer account;
    private Integer tcount;
    private Integer firstT;
    private Integer lastT;
    private Integer batchId;
    private List<String> rowids;
    private List<String> tqrowids;
    private List<TqstubsObj> stubs;

    public Integer getAccount() {
        return this.account;
    }

    public void setAccount(Integer account) {
        this.account = account;
    }

    public Integer getTcount() {
        return this.tcount;
    }

    public void setTcount(Integer tcount) {
        this.tcount = tcount;
    }

    public Integer getFirstT() {
        return this.firstT;
    }

    public void setFirstT(Integer firstT) {
        this.firstT = firstT;
    }

    public Integer getLastT() {
        return this.lastT;
    }

    public void setLastT(Integer lastT) {
        this.lastT = lastT;
    }

    public Integer getBatchId() {
        return this.batchId;
    }

    public void setBatchId(Integer batchId) {
        this.batchId = batchId;
    }

    public List<String> getRowids() {
        return this.rowids;
    }

    public void setRowids(List<String> rowids) {
        this.rowids = rowids;
    }

    public List<String> getTqrowids() {
        return this.tqrowids;
    }

    public void setTqrowids(List<String> tqrowids) {
        this.tqrowids = tqrowids;
    }

    public List<TqstubsObj> getStubs() {
        return this.stubs;
    }

    public void setStubs(List<TqstubsObj> stubs) {
        this.stubs = stubs;
    }


}
