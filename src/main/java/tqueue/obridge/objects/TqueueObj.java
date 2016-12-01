package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class TqueueObj {

    private String xrowid;
    private Integer tqueueId;
    private byte[] xid;
    private String statusCode;
    private String securityDisplayName;
    private String accountDisplayName;
    private Integer securityId;
    private String securityType;
    private Integer accountId;
    private Integer batchId;
    private Date createTs;
    private Date updateTs;
    private String errorMessage;
    private TqueueObj tradeToCorrect;

    public String getXrowid() {
        return this.xrowid;
    }

    public void setXrowid(String xrowid) {
        this.xrowid = xrowid;
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

    public String getStatusCode() {
        return this.statusCode;
    }

    public void setStatusCode(String statusCode) {
        this.statusCode = statusCode;
    }

    public String getSecurityDisplayName() {
        return this.securityDisplayName;
    }

    public void setSecurityDisplayName(String securityDisplayName) {
        this.securityDisplayName = securityDisplayName;
    }

    public String getAccountDisplayName() {
        return this.accountDisplayName;
    }

    public void setAccountDisplayName(String accountDisplayName) {
        this.accountDisplayName = accountDisplayName;
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

    public Date getCreateTs() {
        return this.createTs;
    }

    public void setCreateTs(Date createTs) {
        this.createTs = createTs;
    }

    public Date getUpdateTs() {
        return this.updateTs;
    }

    public void setUpdateTs(Date updateTs) {
        this.updateTs = updateTs;
    }

    public String getErrorMessage() {
        return this.errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public TqueueObj getTradeToCorrect() {
        return this.tradeToCorrect;
    }

    public void setTradeToCorrect(TqueueObj tradeToCorrect) {
        this.tradeToCorrect = tradeToCorrect;
    }


}
