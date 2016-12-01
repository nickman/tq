package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class TqstubsObj {

    private String xrowid;
    private String tqrowid;
    private Integer tqueueId;
    private byte[] xid;
    private Integer securityId;
    private String securityType;
    private Integer accountId;
    private Integer batchId;
    private Timestamp batchTs;

    public String getXrowid() {
        return this.xrowid;
    }

    public void setXrowid(String xrowid) {
        this.xrowid = xrowid;
    }

    public String getTqrowid() {
        return this.tqrowid;
    }

    public void setTqrowid(String tqrowid) {
        this.tqrowid = tqrowid;
    }

    public Integer getTqueueId() {
        return this.tqueueId;
    }

    public void setTqueueId(Integer tqueueId) {
        this.tqueueId = tqueueId;
    }

    public byte[] getXid() {
        return this.xid;
    }

    public void setXid(byte[] xid) {
        this.xid = xid;
    }

    public Integer getSecurityId() {
        return this.securityId;
    }

    public void setSecurityId(Integer securityId) {
        this.securityId = securityId;
    }

    public String getSecurityType() {
        return this.securityType;
    }

    public void setSecurityType(String securityType) {
        this.securityType = securityType;
    }

    public Integer getAccountId() {
        return this.accountId;
    }

    public void setAccountId(Integer accountId) {
        this.accountId = accountId;
    }

    public Integer getBatchId() {
        return this.batchId;
    }

    public void setBatchId(Integer batchId) {
        this.batchId = batchId;
    }

    public Timestamp getBatchTs() {
        return this.batchTs;
    }

    public void setBatchTs(Timestamp batchTs) {
        this.batchTs = batchTs;
    }


}
