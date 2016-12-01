package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class Metricname {

    private Integer segmentcount;
    private String segments;
    private List<String> tags;

    public Integer getSegmentcount() {
        return this.segmentcount;
    }

    public void setSegmentcount(Integer segmentcount) {
        this.segmentcount = segmentcount;
    }

    public String getSegments() {
        return this.segments;
    }

    public void setSegments(String segments) {
        this.segments = segments;
    }

    public List<String> getTags() {
        return this.tags;
    }

    public void setTags(List<String> tags) {
        this.tags = tags;
    }


}
